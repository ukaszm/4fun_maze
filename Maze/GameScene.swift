//
//  GameScene.swift
//  Maze
//
//  Created by Łukasz Majchrzak on 15/03/2017.
//  Copyright © 2017 Łukasz Majchrzak. All rights reserved.
//

import SpriteKit
import GameplayKit

enum CellNaighbour {
    case top, bottom, left, rigth
}

class MazeCell {
    let column: Int
    let row: Int
    var visited = false {
        didSet {
            if visited { bg.color = .gray }
        }
    }

    let bg: SKSpriteNode
    var wallT: SKSpriteNode?
    var wallB: SKSpriteNode?
    var wallL: SKSpriteNode?
    var wallR: SKSpriteNode?
    
    var randomNaighbours: [CellNaighbour] = []
    
    init(column: Int, row: Int, wh: CGFloat) {
        self.column = column
        self.row = row
        
        bg = SKSpriteNode(color: .white, size: CGSize(width: wh, height: wh))
        bg.position = CGPoint(x: wh/2 + CGFloat(column) * wh, y: wh/2 + CGFloat(row) * wh)
        
        wallT = SKSpriteNode(color: .white, size: CGSize(width: wh, height: wh/10))
        wallT?.anchorPoint = CGPoint(x: 0, y: 1)
        wallT?.position = CGPoint(x: -wh/2, y: wh/2)
        bg.addChild(wallT!)
        
        wallB = SKSpriteNode(color: .white, size: CGSize(width: wh, height: wh/10))
        wallB?.anchorPoint = CGPoint(x: 0, y: 0)
        wallB?.position = CGPoint(x: -wh/2, y: -wh/2)
        bg.addChild(wallB!)
        
        wallL = SKSpriteNode(color: .white, size: CGSize(width: wh/10, height: wh))
        wallL?.anchorPoint = CGPoint(x: 0, y: 0)
        wallL?.position = CGPoint(x: -wh/2, y: -wh/2)
        bg.addChild(wallL!)
        
        wallR = SKSpriteNode(color: .white, size: CGSize(width: wh/10, height: wh))
        wallR?.anchorPoint = CGPoint(x: 1, y: 0)
        wallR?.position = CGPoint(x: wh/2, y: -wh/2)
        bg.addChild(wallR!)
        
        var neighbours: [CellNaighbour] = [.top, .bottom, .left, .rigth]
        while !neighbours.isEmpty {
            randomNaighbours.append(neighbours.remove(at: Int(arc4random_uniform(UInt32(neighbours.count)))))
        }
    }
    
    func neighbourIndices (neighbour: CellNaighbour) -> (c: Int, r: Int) {
        switch neighbour {
        case .top:
            return (column, row+1)
        case .bottom:
            return (column, row-1)
        case .left:
            return (column-1, row)
        case .rigth:
            return (column+1, row)
        }
    }
}

class GameScene: SKScene {
    
    var cellWH: CGFloat = 20
    let colNum = 16
    let rowNum = 28
    var lastTimeUpdate: TimeInterval = 0
    var cells: [MazeCell] = []
    var cellsToCheck = [MazeCell]()
    var root: SKNode!
    
    override func didMove(to view: SKView) {
        cellWH = view.frame.height / CGFloat(rowNum) - 0.5
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        root = SKNode()
        root.position = CGPoint(x: -cellWH * CGFloat(colNum) / 2, y: -cellWH * CGFloat(rowNum) / 2)
        addChild(root)
        reset()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        reset()
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        guard !cellsToCheck.isEmpty else { return }
        guard currentTime - lastTimeUpdate >= 0.01 else { return }
        lastTimeUpdate = currentTime
        
        guard let currentCell = cellsToCheck.last else { return }
        guard let nextCell = getNextRandomNeighbour(forCell: currentCell) else {
            let removed = cellsToCheck.removeLast()
            removed.bg.color = .darkGray
            return
        }
        removeWallsBetween(cell: currentCell, nextCell: nextCell)
        nextCell.visited = true
        cellsToCheck.append(nextCell)
    }
}


//MARK: fileprivate
extension GameScene {

    fileprivate func reset() {
        root.removeAllChildren()
        cells = []
        for i in 0..<colNum * rowNum {
            let cell = MazeCell(column: i%colNum, row: i/colNum, wh: cellWH)
            root.addChild(cell.bg)
            cells.append(cell)
        }
        let randomIndex = Int(arc4random_uniform(UInt32(colNum * rowNum)))
        cells[randomIndex].visited = true
        cellsToCheck = [cells[randomIndex]]
    }
    
    fileprivate func getNextRandomNeighbour(forCell cell: MazeCell) -> MazeCell? {
        for neighbour in cell.randomNaighbours {
            let neighbourCR = cell.neighbourIndices(neighbour: neighbour)
            guard isLegalCell(column: neighbourCR.c, row: neighbourCR.r) else { continue }
            let neighbourCell = cellAt(column: neighbourCR.c, row: neighbourCR.r)
            if !neighbourCell.visited { return neighbourCell }
        }
        return nil
    }
    
    fileprivate func removeWallsBetween(cell: MazeCell, nextCell: MazeCell) {
        if cell.row == nextCell.row {
            if cell.column < nextCell.column {
                cell.wallR?.removeFromParent()
                nextCell.wallL?.removeFromParent()
            }
            else {
                cell.wallL?.removeFromParent()
                nextCell.wallR?.removeFromParent()
            }
        }
        else {
            if cell.row < nextCell.row {
                cell.wallT?.removeFromParent()
                nextCell.wallB?.removeFromParent()
            }
            else {
                cell.wallB?.removeFromParent()
                nextCell.wallT?.removeFromParent()
            }
        }
    }
    
    fileprivate func isLegalCell(column: Int, row: Int) -> Bool {
        return column >= 0 && column < colNum && row >= 0 && row < rowNum
    }
    fileprivate func cellAt(column: Int, row: Int) -> MazeCell {
        assert(isLegalCell(column: column, row: row), "Illegal cell indices")
        return cells[column + row * colNum]
    }
}
